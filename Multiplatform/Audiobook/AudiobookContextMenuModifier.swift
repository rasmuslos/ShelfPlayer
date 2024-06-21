//
//  AudiobookContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 26.11.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

internal struct AudiobookContextMenuModifier: ViewModifier {
    let audiobook: Audiobook
    
    @State private var authorId: String?
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    audiobook.startPlayback()
                } label: {
                    Label("play", systemImage: "play")
                }
                
                Divider()
                
                NavigationLink(destination: AudiobookView(viewModel: .init(audiobook: audiobook))) {
                    Label("audiobook.view", systemImage: "book")
                }
                
                if let authorId = authorId {
                    NavigationLink(destination: AuthorLoadView(authorId: authorId)) {
                        Label("author.view", systemImage: "person")
                        
                        if let author = audiobook.author {
                            Text(author)
                        }
                    }
                }
                
                ForEach(audiobook.series, id: \.name) { series in
                    NavigationLink(destination: SeriesLoadView(series: series)) {
                        Label("series.view", systemImage: "text.justify.leading")
                        Text(series.name)
                    }
                }
                
                Divider()
                
                ProgressButton(item: audiobook)
                DownloadButton(item: audiobook)
            } preview: {
                VStack(alignment: .leading, spacing: 2) {
                    ItemStatusImage(item: audiobook, aspectRatio: .none)
                        .padding(.bottom, 10)
                    
                    Text(audiobook.name)
                        .font(.headline)
                        .modifier(SerifModifier())
                    
                    if let author = audiobook.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let narrator = audiobook.narrator {
                        Text(narrator)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 240)
                .padding(20)
                .task {
                    await loadAuthorID()
                }
            }
    }
    
    private nonisolated func loadAuthorID() async {
        guard let author = await audiobook.author else {
            return
        }
        
        guard let authorId = try? await AudiobookshelfClient.shared.getAuthorId(name: author, libraryId: audiobook.libraryId) else {
            return
        }
        
        await MainActor.run {
            self.authorId = authorId
        }
    }
}

#Preview {
    Text(verbatim: ":)")
        .modifier(AudiobookContextMenuModifier(audiobook: Audiobook.fixture))
}
