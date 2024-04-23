//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SPBase
import SPOffline

struct ProgressButton: View {
    let item: PlayableItem
    let tint: Bool
    
    let entity: ItemProgress
    
    @MainActor
    init(item: PlayableItem, tint: Bool = false) {
        self.item = item
        self.tint = tint
        
        entity = OfflineManager.shared.requireProgressEntity(item: item)
    }
    
    var body: some View {
        Button {
            Task {
                await item.setProgress(finished: entity.progress < 1)
            }
        } label: {
            if entity.progress >= 1 {
                Label("progress.reset", systemImage: "minus")
                    .tint(tint ? .red : .primary)
            } else {
                Label("progress.complete", systemImage: "checkmark")
                    .tint(tint ? .accentColor : .primary)
            }
        }
    }
}

#Preview {
    ProgressButton(item: Episode.fixture)
}
