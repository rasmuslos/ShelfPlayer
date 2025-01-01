//
//  DownloadIndicator.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 22.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct DownloadIndicator: View {
    let itemID: ItemIdentifier
    // let offlineTracker: DownloadTracker
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        // offlineTracker = .init(item)
    }
    
    var body: some View {
        /*
        if offlineTracker.status == .downloaded {
            Label("download", systemImage: "arrow.down.circle.fill")
                .labelStyle(.iconOnly)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if offlineTracker.status == .working {
            DownloadProgressIndicator(itemId: itemId, small: true)
        }
         */
        Text("abc")
    }
}

internal struct DownloadProgressIndicator: View {
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
        /*
        .onReceive(NotificationCenter.default.publisher(for: OfflineManager.downloadProgressUpdatedNotification)) { _ in
            downloadProgress = AudiobookshelfClient.defaults.double(forKey: "downloadTotalProgress_\(itemId)")
        }
         */
    }
}
