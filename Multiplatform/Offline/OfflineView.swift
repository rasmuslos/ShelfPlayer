//
//  OfflineView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.04.25.
//

import SwiftUI
import ShelfPlayerKit

struct OfflineView: View {
    @Environment(Satellite.self) private var satellite
    
    @State private var audiobooks: [Audiobook] = []
    // @State private var podcasts: [Podcast] = .init(repeating: .fixture, count: 7)
    
    @ViewBuilder
    private var goOnlineButton: some View {
        Button("navigation.offline.disable", systemImage: "network") {
            RFNotification[.changeOfflineMode].send(false)
        }
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            NavigationStack {
                List {
                    if !audiobooks.isEmpty {
                        Section("panel.offline.audiobooks") {
                            ForEach(audiobooks) {
                                OfflineAudiobookRow(audiobook: $0)
                            }
                        }
                    }
                    
                    goOnlineButton
                }
                .navigationTitle("panel.offline")
                .modifier(CompactPreferencesToolbarModifier())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        goOnlineButton
                    }
                }
            }
            .modifier(CompactPlaybackModifier(ready: true))
            .environment(\.playbackBottomOffset, max(16, geometryProxy.safeAreaInsets.bottom))
            .onAppear {
                loadItems()
            }
            .refreshable {
                loadItems()
            }
            .onReceive(RFNotification[.downloadStatusChanged].publisher()) { itemID, _ in
                loadItems()
            }
        }
    }
    
    private nonisolated func loadItems() {
        Task {
            let audiobooks = try await PersistenceManager.shared.download.audiobooks()
            
            await MainActor.withAnimation {
                self.audiobooks = audiobooks
            }
        }
    }
}

private struct OfflineAudiobookRow: View {
    @Environment(Satellite.self) private var satellite
    
    let audiobook: Audiobook
    @State private var progress: ProgressTracker
    
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        _progress = .init(initialValue: .init(itemID: audiobook.id))
    }
    
    var body: some View {
        Button {
            satellite.start(audiobook.id)
        } label: {
            HStack(spacing: 8) {
                ItemImage(item: audiobook, size: .small)
                    .frame(width: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(audiobook.name)
                        .lineLimit(1)
                        .font(.headline)
                    
                    Text(audiobook.authors, format: .list(type: .and, width: .short))
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
                
                if let progress = progress.progress {
                    CircleProgressIndicator(progress: progress)
                        .frame(width: 16)
                } else {
                    ProgressView()
                        .scaleEffect(0.75)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(satellite.isLoading(observing: audiobook.id))
        .modifier(PlayableItemSwipeActionsModifier(itemID: audiobook.id))
        .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

#if DEBUG
#Preview {
    OfflineView()
        .previewEnvironment()
}
#endif
