//
//  AudiobookContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 26.11.23.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

internal struct AudiobookContextMenuModifier: ViewModifier {
    let audiobook: Audiobook
    
    @State private var authorId: String?
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    Task {
                        try await AudioPlayer.shared.play(audiobook)
                    }
                } label: {
                    Label("play", systemImage: "play.fill")
                }
                
                QueueButton(item: audiobook)
                
                Divider()
                
                NavigationLink(destination: AudiobookView(audiobook)) {
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
                
                DownloadButton(item: audiobook)
                
                ProgressButton(item: audiobook)
            } preview: {
                VStack(alignment: .leading, spacing: 2) {
                    ItemStatusImage(item: audiobook, aspectRatio: .none)
                        .padding(.bottom, 12)
                    
                    Text(audiobook.name)
                        .font(.headline)
                        .modifier(SerifModifier())
                    
                    if let author = audiobook.author {
                        Text("readBy \(author)")
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
        
        guard let authorId = try? await AudiobookshelfClient.shared.authorID(name: author, libraryId: audiobook.libraryId) else {
            return
        }
        
        await MainActor.run {
            self.authorId = authorId
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .modifier(AudiobookContextMenuModifier(audiobook: Audiobook.fixture))
}
#endif
