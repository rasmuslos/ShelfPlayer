//
//  OfflineView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import SwiftUI
import TipKit
import ShelfPlayerKit
import SPPlayback

internal struct OfflineView: View {
    @State private var accountSheetPresented = false
    
    @State private var audiobooks = [Audiobook]()
    @State private var podcasts = [Podcast: [Episode]]()
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TipView(SiriOfflineTip())
                        .tipBackground(.background.tertiary)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                
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
                        NotificationCenter.default.post(name: SelectLibraryModifier.changeLibraryNotification, object: nil, userInfo: [
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
            .modifier(NowPlaying.BackgroundModifier(bottomOffset: -40))
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

private struct SiriOfflineTip: Tip {
    var title: Text {
        .init("tip.offlineSiri.title")
    }
    var message: Text? {
        .init("tip.offlineSiri.message")
    }
    
    var image: Image? {
        .init(systemName: "network.slash")
    }
}

#Preview {
    OfflineView()
        .environment(NowPlaying.ViewModel())
}
