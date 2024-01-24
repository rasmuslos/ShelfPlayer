//
//  AudiobookView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SPBase

struct AudiobookView: View {
    @Environment(\.libraryId) var libraryId
    
    let audiobook: Audiobook
    
    @State var navigationBarVisible = false
    @State var chapters: PlayableItem.Chapters?
    
    @State var authorId: String?
    @State var seriesId: String?
    
    @State var audiobooksByAuthor = [Audiobook]()
    @State var audiobooksInSeries = [Audiobook]()
    
    let divider: some View = Divider()
        .padding(.horizontal)
        .padding(.vertical, 10)
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Header(audiobook: audiobook, authorId: $authorId, seriesId: $seriesId, navigationBarVisible: $navigationBarVisible)
                    .padding()
                
                divider
                
                Description(description: audiobook.description)
                    .padding()
                
                if let chapters = chapters, chapters.count > 1 {
                    divider
                    ChaptersList(chapters: chapters)
                        .padding()
                }
                
                if audiobooksInSeries.count > 1 {
                    divider
                    AudiobooksRowContainer(title: "Also in series", audiobooks: audiobooksInSeries, amount: 4, navigatable: true)
                }
                
                if audiobooksByAuthor.count > 1 {
                    divider
                    AudiobooksRowContainer(title: "Also by \(audiobook.author ?? "the author")", audiobooks: audiobooksByAuthor, amount: 4, navigatable: true)
                }
                
                Spacer()
            }
        }
        .modifier(ToolbarModifier(audiobook: audiobook, navigationBarVisible: $navigationBarVisible, authorId: $authorId, seriesId: $seriesId))
        .modifier(NowPlayingBarSafeAreaModifier())
        .onAppear(perform: fetchData)
    }
}

// MARK: Helper

extension AudiobookView {
    func fetchData() {
        fetchAuthorData()
        fetchSeriesData()
        fetchAudiobookData()
    }
    
    func fetchAudiobookData() {
        Task.detached {
            (_, _, chapters) = try await AudiobookshelfClient.shared.getItem(itemId: audiobook.id, episodeId: nil)
        }
    }
    
    func fetchAuthorData() {
        Task.detached {
            if let author = audiobook.author, let authorId = try? await AudiobookshelfClient.shared.getAuthorId(name: author, libraryId: libraryId) {
                self.authorId = authorId
                audiobooksByAuthor = (try? await AudiobookshelfClient.shared.getAuthorData(authorId: authorId, libraryId: libraryId).1) ?? []
            }
        }
    }
    
    func fetchSeriesData() {
        Task.detached {
            if let seriesId = audiobook.series.id {
                self.seriesId = seriesId
            } else if let series = audiobook.series.name {
                seriesId = await AudiobookshelfClient.shared.getSeriesId(name: series, libraryId: libraryId)
            } else if let series = audiobook.series.audiobookSeriesName, let seriesName = series.split(separator: "#").first?.dropLast() {
                seriesId = await AudiobookshelfClient.shared.getSeriesId(name: String(seriesName), libraryId: libraryId)
            }
            
            if let seriesId = seriesId {
                audiobooksInSeries = (try? await AudiobookshelfClient.shared.getAudiobooks(seriesId: seriesId, libraryId: libraryId)) ?? []
            }
        }
    }
}

#Preview {
    NavigationStack {
        AudiobookView(audiobook: Audiobook.fixture)
    }
}
