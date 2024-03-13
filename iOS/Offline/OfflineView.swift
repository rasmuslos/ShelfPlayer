//
//  OfflineView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct OfflineView: View {
    @State var accountSheetPresented = false
    
    @State var audiobooks = [Audiobook]()
    @State var podcasts = [Podcast: [Episode]]()
    
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
                    NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
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
            .modifier(NowPlayingBarSafeAreaModifier())
            .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in Task { try? await loadItems() }}
        }
        .modifier(NowPlayingBarModifier())
        .sheet(isPresented: $accountSheetPresented) { AccountSheet() }
    }
}

extension OfflineView {
    func loadItems() async throws {
        (audiobooks, podcasts) = try await (OfflineManager.shared.getAudiobooks(), OfflineManager.shared.getPodcasts())
    }
}

#Preview {
    OfflineView()
}
