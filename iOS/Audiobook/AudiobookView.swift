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
    
    let viewModel: AudiobookViewModel
    
    init(audiobook: Audiobook) {
        viewModel = .init(audiobook: audiobook)
    }
    
    let divider: some View = Divider()
        .padding(.horizontal)
        .padding(.vertical, 10)
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Header()
                    .padding()
                
                divider
                
                Description(description: viewModel.audiobook.description)
                    .padding()
                
                if let chapters = viewModel.chapters, chapters.count > 1 {
                    divider
                    ChaptersList(chapters: chapters)
                        .padding()
                }
                
                if viewModel.audiobooksInSeries.count > 1 {
                    divider
                    AudiobooksRowContainer(title: String(localized: "audiobook.similar.series"), audiobooks: viewModel.audiobooksInSeries, amount: 4, navigatable: true)
                }
                
                if viewModel.audiobooksByAuthor.count > 1, let author = viewModel.audiobook.author {
                    divider
                    AudiobooksRowContainer(title: String(localized: "audiobook.similar.author \(author)"), audiobooks: viewModel.audiobooksByAuthor, amount: 4, navigatable: true)
                }
                
                Spacer()
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .modifier(ToolbarModifier())
        .environment(viewModel)
        .task { await viewModel.fetchData(libraryId: libraryId) }
    }
}

#Preview {
    NavigationStack {
        AudiobookView(audiobook: Audiobook.fixture)
    }
}
