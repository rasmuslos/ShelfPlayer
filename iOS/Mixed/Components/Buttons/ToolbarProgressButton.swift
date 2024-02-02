//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SPBase
import SPOffline

struct ToolbarProgressButton: View {
    let item: PlayableItem
    let entity: OfflineProgress
    
    @MainActor
    init(item: PlayableItem) {
        self.item = item
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
            } else {
                Label("progress.complete", systemImage: "checkmark")
            }
        }
    }
}

#Preview {
    ToolbarProgressButton(item: Episode.fixture)
}
