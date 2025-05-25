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
            RFNotification[.changeOfflineMode].send(payload: false)
        }
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            NavigationStack {
                List {
                    if !audiobooks.isEmpty {
                        Section("row.downloaded.audiobooks") {
                            ForEach(audiobooks) { audiobook in
                                ItemCompactRow(item: audiobook) {
                                    satellite.start(audiobook.id)
                                }
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
            .onReceive(RFNotification[.downloadStatusChanged].publisher()) { _ in
                loadItems()
            }
        }
    }
    
    private nonisolated func loadItems() {
        Task {
            let audiobooks = try await PersistenceManager.shared.download.audiobooks()
            // let episodes = try await PersistenceManager.shared.download.episodes()
            
            await MainActor.withAnimation {
                self.audiobooks = audiobooks
            }
        }
    }
}

#if DEBUG
#Preview {
    OfflineView()
        .previewEnvironment()
}
#endif
