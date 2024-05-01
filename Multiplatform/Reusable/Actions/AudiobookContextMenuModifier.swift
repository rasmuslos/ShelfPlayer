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

struct AudiobookContextMenuModifier: ViewModifier {
    let audiobook: Audiobook
    let offlineTracker: ItemOfflineTracker
    
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        offlineTracker = audiobook.offlineTracker
    }
    
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
                        
                        if let author = audiobook.author {
                            Text(author)
                        }
                    }
                }
                
                ForEach(audiobook.series, id: \.name) { series in
                    NavigationLink(destination: SeriesLoadView(series: series)) {
                        Text("series.view")
                        Text(series.name)
                    }
                }
                
                Divider()
                
                ProgressButton(item: audiobook)
                DownloadButton(item: audiobook)
            } preview: {
                VStack(alignment: .leading) {
                    ItemStatusImage(item: audiobook)
                    
                    Text(audiobook.name)
                        .font(.headline)
                        .modifier(SerifModifier())
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
                .padding(20)
                .onAppear {
                    Task.detached {
                        if let author = audiobook.author {
                            authorId = try? await AudiobookshelfClient.shared.getAuthorId(name: author, libraryId: audiobook.libraryId)
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
