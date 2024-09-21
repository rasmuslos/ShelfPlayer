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
                if !audiobooks.isEmpty {
                    Section("downloads.audiobooks") {
                        OfflineAudiobookList(audiobooks: audiobooks.sorted())
                    }
                }
                
                if !podcasts.isEmpty {
                    Section("downloads.podcasts") {
                        OfflinePodcastList(podcasts: podcasts)
                    }
                }
                
                Group {
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
                .foregroundStyle(.primary)
            }
            .navigationTitle("offline.title")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(NowPlaying.SafeAreaModifier())
            .task {
                await loadItems()
            }
            .refreshable {
                await loadItems()
            }
        }
        .modifier(NowPlaying.CompactModifier(bottomOffset: 40))
        .sheet(isPresented: $accountSheetPresented) {
            AccountSheet()
        }
        .environment(\.libraryId, "offline")
        .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in
            Task {
                await loadItems()
            }
        }
    }
    
    private nonisolated func loadItems() async {
        guard let (audiobooks, podcasts) = try? (OfflineManager.shared.audiobooks(), OfflineManager.shared.podcasts()) else {
            return
        }
        
        await MainActor.withAnimation {
            self.audiobooks = audiobooks
            self.podcasts = podcasts
        }
    }
}

#Preview {
    OfflineView()
}
