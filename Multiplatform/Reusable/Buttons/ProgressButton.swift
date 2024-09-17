//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SPFoundation
import SPOffline

internal struct ProgressButton: View {
    let item: PlayableItem
    let tint: Bool
    
    @State private var progressEntity: ProgressEntity
    
    init(item: PlayableItem, tint: Bool = false) {
        self.item = item
        self.tint = tint
        
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
        progressEntity.beginReceivingUpdates()
    }
    
    private var finished: Bool {
        progressEntity.progress >= 1
    }
    
    var body: some View {
        Button {
            Task {
                try await item.finished(progressEntity.progress < 1)
            }
        } label: {
            Label(finished ? "progress.reset" : "progress.complete", systemImage: finished ? "minus" : "checkmark")
                .contentTransition(.symbolEffect)
                .tint(tint ? finished ? .red : .accentColor : .primary)
        }
    }
}

#if DEBUG
#Preview {
    ProgressButton(item: Episode.fixture)
}
#endif
