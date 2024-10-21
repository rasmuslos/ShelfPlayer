//
//  OfflineView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import SwiftUI
import TipKit
import Defaults
import ShelfPlayerKit
import SPPlayback

internal struct OfflineView: View {
    @Default(.offlineAudiobooksSortOrder) private var offlineAudiobooksSortOrder
    @Default(.offlineAudiobooksAscending) private var offlineAudiobooksAscending
    
    @State private var accountSheetPresented = false
    
    @State private var _audiobooks = [Audiobook]()
    @State private var podcasts = [Podcast: [Episode]]()
    
    private var audiobooks: [Audiobook] {
        return AudiobookSortFilter.sort(audiobooks: _audiobooks, order: offlineAudiobooksSortOrder, ascending: offlineAudiobooksAscending)
    }
    
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
            .toolbar {
                Menu {
                    AudiobookSortFilter.SortOrders(options: AudiobookSortOrder.allCases,
                                                   sortOrder: $offlineAudiobooksSortOrder,
                                                   ascending: $offlineAudiobooksAscending)
                } label: {
                    Label("filterSort", systemImage: "arrowshape.\(offlineAudiobooksAscending ? "up" : "down").circle")
                        .contentTransition(.symbolEffect(.replace.upUp))
                }
            }
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
        
        let sorted = Dictionary(uniqueKeysWithValues: podcasts.sorted(by: { $0.key.sortName < $1.key.sortName }))
        
        await MainActor.withAnimation {
            self._audiobooks = audiobooks
            self.podcasts = sorted
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
