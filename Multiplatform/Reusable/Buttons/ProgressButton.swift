//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SPFoundation
import SPOffline

struct ProgressButton: View {
    let item: PlayableItem
    let tint: Bool
    
    @State private var progressEntity: ItemProgress
    
    init(item: PlayableItem, tint: Bool = false) {
        self.item = item
        self.tint = tint
        
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
    }
    
    var body: some View {
        Button {
            Task {
                try await item.finished(progressEntity.progress < 1)
            }
        } label: {
            if progressEntity.progress >= 1 {
                Label("progress.reset", systemImage: "minus")
                    .tint(tint ? .red : .primary)
            } else {
                Label("progress.complete", systemImage: "checkmark")
                    .tint(tint ? .accentColor : .primary)
            }
        }
    }
}

#if DEBUG
#Preview {
    ProgressButton(item: Episode.fixture)
}
#endif
