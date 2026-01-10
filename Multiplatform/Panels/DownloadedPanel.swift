//
//  DownloadedPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.01.26.
//

import SwiftUI
import ShelfPlayback

struct DownloadedPanel: View {
    @Environment(\.library) private var library
    
    @State private var episodes = [Episode]()
    @State private var audiobooks = [Audiobook]()
    
    var isEmpty: Bool {
        episodes.isEmpty && audiobooks.isEmpty
    }
    
    var body: some View {
        Group {
            if isEmpty {
                EmptyCollectionView()
            } else {
                List {
                    ForEach(episodes) {
                        EpisodeList.Row(episode: $0, context: .collection)
                    }
                    ForEach(audiobooks) {
                        AudiobookList.Row(audiobook: $0)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("item.downloaded")
        .largeTitleDisplayMode()
        .task {
            load()
        }
        .refreshable {
            load()
        }
        .onReceive(RFNotification[.downloadStatusChanged].publisher()) { _ in
            load()
        }
    }
    
    private func load() {
        Task {
            guard let library else {
                #if DEBUG
                episodes = .init(repeating: .fixture, count: 3)
                audiobooks = .init(repeating: .fixture, count: 3)
                #endif
                
                return
            }
            
            (episodes, audiobooks) = try (
                await PersistenceManager.shared.download.episodes(in: library.id.libraryID),
                await PersistenceManager.shared.download.audiobooks(in: library.id.libraryID),
            )
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DownloadedPanel()
    }
    .previewEnvironment()
}
#endif
