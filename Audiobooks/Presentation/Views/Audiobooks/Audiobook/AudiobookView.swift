//
//  AudiobookView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct AudiobookView: View {
    @Environment(\.libraryId) var libraryId
    
    let audiobook: Audiobook
    
    @State var navbarVisible = false
    
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
                Header(audiobook: audiobook, authorId: $authorId, seriesId: $seriesId, navbarVisible: $navbarVisible)
                .padding()
                
                divider
                
                HStack {
                    VStack(alignment: .leading) {
                        if let description = audiobook.description {
                            Text("Description")
                                .bold()
                                .underline()
                            
                            Text(description)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                if !audiobooksInSeries.isEmpty {
                    divider
                    
                    AudiobooksRowContainer(title: "Also in series", audiobooks: audiobooksInSeries, amount: 4)
                }
                
                if !audiobooksByAuthor.isEmpty {
                    divider
                    
                    AudiobooksRowContainer(title: "Also by \(audiobook.author ?? "the author")", audiobooks: audiobooksByAuthor, amount: 4)
                }
                
                Spacer()
            }
        }
        .modifier(ToolbarModifier(audiobook: audiobook, navbarVisible: $navbarVisible))
        .onAppear {
            getAuthorData()
            getSeriesData()
        }
    }
}

// MARK: Helper

extension AudiobookView {
    func getAuthorData() {
        Task.detached {
            if let author = audiobook.author, let authorId = await AudiobookshelfClient.shared.getAuthorIdByName(author, libraryId: libraryId) {
                    self.authorId = authorId
                    audiobooksByAuthor = (try? await AudiobookshelfClient.shared.getAudiobooksByAuthor(authorId: authorId, libraryId: libraryId)) ?? []
            }
        }
    }
    func getSeriesData() {
        Task.detached {
            if let series = audiobook.series, let seriesName = series.split(separator: "#").first?.dropLast() {
                if let seriesId = await AudiobookshelfClient.shared.getSeriesIdByName(String(seriesName), libraryId: libraryId) {
                    self.seriesId = seriesId
                    audiobooksInSeries = (try? await AudiobookshelfClient.shared.getAudiobooksInSeries(seriesId: seriesId, libraryId: libraryId)) ?? []
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AudiobookView(audiobook: Audiobook.fixture)
    }
}
