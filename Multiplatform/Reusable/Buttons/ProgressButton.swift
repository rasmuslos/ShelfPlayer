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
    
    var body: some View {
        Button(role: progressEntity.isFinished ? .destructive : nil) {
            Task {
                try await item.finished(!progressEntity.isFinished)
            }
        } label: {
            Label(progressEntity.isFinished ? "progress.finished.unset" : "progress.finished.set", systemImage: progressEntity.isFinished ? "minus" : "checkmark")
                .contentTransition(.symbolEffect)
                .symbolVariant(tint ? .none : .circle)
                .tint(tint ? progressEntity.isFinished ? .red : .accentColor : nil)
        }
    }
}

#if DEBUG
#Preview {
    ProgressButton(item: Episode.fixture)
}
#endif
