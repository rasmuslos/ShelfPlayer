//
//  DownloadIndicator.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 22.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct DownloadIndicator: View {
    let itemId: String
    let offlineTracker: ItemOfflineTracker
    
    init(item: PlayableItem) {
        itemId = item.id
        offlineTracker = .init(item)
    }
    
    var body: some View {
        if offlineTracker.status == .downloaded {
            Label("download", systemImage: "arrow.down.circle.fill")
                .labelStyle(.iconOnly)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if offlineTracker.status == .working {
            DownloadProgressIndicator(itemId: itemId, small: true)
        }
    }
}

struct DownloadProgressIndicator: View {
    let itemId: String
    let small: Bool
    
    @State private var downloadProgress: CGFloat = 0.0
    
    var body: some View {
        Group {
            if downloadProgress <= 0 {
                ProgressIndicator()
                    .scaleEffect(small ? 0.75 : 1)
            } else {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: downloadProgress)
                        .stroke(Color.accentColor, style: .init(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: small ? 10 : 19)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: OfflineManager.downloadProgressUpdatedNotification)) { _ in
            downloadProgress = AudiobookshelfClient.defaults.double(forKey: "downloadTotalProgress_\(itemId)")
        }
    }
}
