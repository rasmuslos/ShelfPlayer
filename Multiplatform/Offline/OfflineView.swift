//
//  OfflineView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

struct OfflineView: View {
    @State var accountSheetPresented = false
    
    @State var audiobooks = [Audiobook]()
    @State var podcasts = [Podcast: [Episode]]()
    
    // TODO: ADD A REUSABLE QUEUE (account menu, too)
    
    var body: some View {
        NavigationStack {
            List {
                Section("downloads.audiobooks") {
                    if audiobooks.isEmpty {
                        Text("downloads.empty")
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)
                    }
                    
                    OfflineAudiobookList(audiobooks: audiobooks)
                }
                
                Section("downloads.podcasts") {
                    if podcasts.isEmpty {
                        Text("downloads.empty")
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)
                    }
                    
                    OfflinePodcastList(podcasts: podcasts)
                }
                
                Button {
                    NotificationCenter.default.post(name: Library.changeLibraryNotification, object: nil, userInfo: [
                        "offline": false,
                    ])
                } label: {
                    Label("offline.disable", systemImage: "network")
                }
                Button {
                    accountSheetPresented.toggle()
                } label: {
                    Label("account.manage", systemImage: "server.rack")
                }
            }
            .navigationTitle("title.offline")
            .task { try? await loadItems() }
            .refreshable { try? await loadItems() }
            .modifier(NowPlaying.SafeAreaModifier())
            .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in Task { try? await loadItems() }}
        }
        .modifier(NowPlaying.CompactBarModifier(offset: 30))
        .modifier(NowPlaying.CompactViewModifier(offset: 39))
        .sheet(isPresented: $accountSheetPresented) { AccountSheet() }
        .environment(\.libraryId, "offline")
    }
}

extension OfflineView {
    nonisolated func loadItems() async throws {
        guard let (audiobooks, podcasts) = try? await (OfflineManager.shared.audiobooks(), OfflineManager.shared.podcasts()) else {
            return
        }
        
        await MainActor.run {
            self.audiobooks = audiobooks
            self.podcasts = podcasts
        }
    }
}

#Preview {
    OfflineView()
}
