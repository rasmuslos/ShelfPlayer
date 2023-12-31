//
//  ToolbarProgressButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import ShelfPlayerKit

struct ToolbarProgressButton: View {
    let item: PlayableItem
    
    @State var progress: OfflineProgress?
    
    var body: some View {
        Button {
            Task {
                await item.setProgress(finished: (progress?.progress ?? 0) < 1)
            }
        } label: {
            if let progress = progress, progress.progress >= 1 {
                Label("progress.reset", systemImage: "minus")
            } else {
                Label("progress.complete", systemImage: "checkmark")
            }
        }
        .onAppear(perform: fetchProgress)
        .onReceive(NotificationCenter.default.publisher(for: OfflineManager.progressCreatedNotification)) { _ in
            fetchProgress()
        }
    }
}

// MARK: Helper

extension ToolbarProgressButton {
    @MainActor
    private func fetchProgress() {
        progress = OfflineManager.shared.getProgress(item: item)
    }
}

#Preview {
    ToolbarProgressButton(item: Episode.fixture)
}
