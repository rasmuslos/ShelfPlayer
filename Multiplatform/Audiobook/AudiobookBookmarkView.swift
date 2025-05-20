//
//  AudiobookBookmarkView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.05.25.
//

import SwiftUI
import ShelfPlayerKit

struct AudiobookBookmarkView: View {
    @Environment(Satellite.self) private var satellite
    
    let audiobook: Audiobook
    
    @State private var isLoading = true
    @State private var bookmarks = [Bookmark]()
    
    @ViewBuilder
    private func row(for bookmark: Bookmark) -> some View {
        let time = TimeInterval(bookmark.time)
        
        TimeRow(title: bookmark.note, time: time, isActive: false, isFinished: false) {
            satellite.start(audiobook.id, at: time)
        }
    }
    
    var body: some View {
        Group {
            if bookmarks.isEmpty {
                if isLoading {
                    LoadingView()
                } else {
                    EmptyCollectionView()
                }
            } else {
                List {
                    ForEach(bookmarks) {
                        row(for: $0)
                    }
                    .onDelete {
                        guard let currentItemID = satellite.nowPlayingItemID else {
                            return
                        }
                        
                        for index in $0 {
                            satellite.deleteBookmark(at: satellite.bookmarks[index].time, from: currentItemID)
                        }
                    }
                }
                .listStyle(.plain)
                .toolbar {
                    EditButton()
                }
            }
        }
        .navigationTitle(audiobook.name)
        .toolbarTitleDisplayMode(.inline)
        .task {
            load()
        }
        .refreshable {
            load()
        }
    }
    
    private nonisolated func load() {
        Task {
            #if DEBUG
            if audiobook == .fixture {
                await MainActor.withAnimation {
                    self.bookmarks = Array(repeating: .init(itemID: .fixture, time: 500, note: "Test", created: .now), count: 7)
                }
                
                return
            }
            #endif
            
            await MainActor.withAnimation {
                isLoading = true
            }
            
            do {
                let bookmarks = try await PersistenceManager.shared.bookmark[audiobook.id]
                
                await MainActor.withAnimation {
                    self.bookmarks = bookmarks
                }
            } catch {
                await MainActor.run {
                    satellite.notifyError.toggle()
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookBookmarkView(audiobook: .fixture)
    }
    .previewEnvironment()
}
#endif
