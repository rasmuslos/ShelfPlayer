//
//  Account+Downloads.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 06.05.24.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

extension AccountSheet {
    struct Downloads: View {
        @State private var downloadStatus: OfflineManager.DownloadStatus?
        
        var body: some View {
            Section("account.downloads") {
                if let downloadStatus = downloadStatus, !(downloadStatus.0.isEmpty && downloadStatus.1.isEmpty) {
                    ForEach(Array(downloadStatus.0.keys).sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }) { audiobook in
                        HStack {
                            ItemImage(image: audiobook.image)
                                .frame(width: 55)
                            
                            VStack(alignment: .leading) {
                                Text(audiobook.name)
                                    .modifier(SerifModifier())
                                if let author = audiobook.author {
                                    Text(author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .lineLimit(1)
                            
                            Spacer()
                            
                            if let status = downloadStatus.0[audiobook] {
                                if status.0 == 0 && status.1 == 1 {
                                    ProgressIndicator()
                                } else {
                                    Text(verbatim: "\(status.0)/\(status.1)")
                                        .fontDesign(.rounded)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                OfflineManager.shared.delete(audiobookId: audiobook.id)
                            } label: {
                                Label("download.remove", systemImage: "trash.fill")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                    
                    ForEach(Array(downloadStatus.1.keys).sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }) { podcast in
                        HStack {
                            ItemImage(image: podcast.image)
                                .frame(width: 55)
                            
                            VStack(alignment: .leading) {
                                Text(podcast.name)
                                
                                if let author = podcast.author {
                                    Text(author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .lineLimit(1)
                            
                            Spacer()
                            
                            if let status = downloadStatus.1[podcast] {
                                Text(verbatim: "\(status.0)/\(status.1)")
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                try! OfflineManager.shared.delete(podcastId: podcast.id)
                            } label: {
                                Label("download.remove", systemImage: "trash.fill")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                } else {
                    Text("accounts.downloads.empty")
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                downloadStatus = try? await OfflineManager.shared.getDownloadStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in
                Task.detached { @MainActor in
                    downloadStatus = try? await OfflineManager.shared.getDownloadStatus()
                }
            }
        }
    }
}
