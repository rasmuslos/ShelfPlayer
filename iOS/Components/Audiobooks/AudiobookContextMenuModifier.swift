//
//  AudiobookContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 26.11.23.
//

import SwiftUI
import ShelfPlayerKit

struct AudiobookContextMenuModifier: ViewModifier {
    let audiobook: Audiobook
    
    @State var authorId: String?
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                NavigationLink(destination: AudiobookView(audiobook: audiobook)) {
                    Label("audiobook.view", systemImage: "book")
                }
                
                if let authorId = authorId {
                    NavigationLink(destination: AuthorLoadView(authorId: authorId)) {
                        Label("author.view", systemImage: "person")
                        Text(audiobook.author!)
                    }
                }
                
                if let seriesId = audiobook.series.id {
                    NavigationLink(destination: SeriesLoadView(seriesId: seriesId)) {
                        Label("series.view", systemImage: "text.justify.leading")
                        Text(audiobook.series.name ?? audiobook.series.audiobookSeriesName!)
                    }
                }
                
                Divider()
                
                ToolbarProgressButton(item: audiobook)
                
                if audiobook.offline == .none {
                    Button {
                        Task {
                            try! await OfflineManager.shared.download(audiobook: audiobook)
                        }
                    } label: {
                        Label("download", systemImage: "arrow.down")
                    }
                } else {
                    Button {
                        try? OfflineManager.shared.delete(audiobookId: audiobook.id)
                    } label: {
                        Label("download.remove", systemImage: "trash")
                    }
                }
            } preview: {
                VStack(alignment: .leading) {
                    ItemProgressImage(item: audiobook)
                    
                    Text(audiobook.name)
                        .font(.headline)
                        .fontDesign(.serif)
                        .padding(.top, 10)
                    
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
                .frame(width: 250)
                .padding()
                .onAppear {
                    Task.detached {
                        if let author = audiobook.author {
                            authorId = await AudiobookshelfClient.shared.getAuthorId(name: author, libraryId: audiobook.libraryId)
                        }
                    }
                }
            }
    }
}

#Preview {
    Text(":)")
        .modifier(AudiobookContextMenuModifier(audiobook: Audiobook.fixture))
}
