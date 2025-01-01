//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SPFoundation
import SPPersistence

internal struct ProgressButton: View {
    let item: PlayableItem
    let tint: Bool
    let callback: (() -> Void)?
    
    @State private var progressEntity: ProgressEntity?
    
    init(item: PlayableItem, tint: Bool = false, callback: (() -> Void)? = nil) {
        self.item = item
        self.tint = tint
        self.callback = callback
        
        // _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
    }
    
    var body: some View {
        Button {
            Task {
                // try await item.finished(!progressEntity.isFinished)
                callback?()
            }
        } label: {
            /*
            Label(progressEntity.isFinished ? "progress.finished.unset" : "progress.finished.set", systemImage: progressEntity.isFinished ? "minus" : "checkmark")
                .contentTransition(.symbolEffect)
                .symbolVariant(tint ? .none : .circle)
                .tint(tint ? progressEntity.isFinished ? .red : .green : nil)
            */
        }
    }
}

#if DEBUG
#Preview {
    ProgressButton(item: Episode.fixture)
}
#endif
