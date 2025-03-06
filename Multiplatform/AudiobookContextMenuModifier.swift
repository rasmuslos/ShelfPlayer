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
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                QueuePlayButton(item: audiobook)
                QueueButton(item: audiobook)
                
                Divider()
                
                NavigationLink(destination: AudiobookView(audiobook)) {
                    Label("audiobook.view", systemImage: "book")
                }
                
                ItemMenu(authors: audiobook.authors)
                ItemMenu(series: audiobook.series)
                
                Divider()
                
                ProgressButton(item: audiobook)
                DownloadButton(item: audiobook)
            } preview: {
                Preview(audiobook: audiobook)
            }
    }
}

internal extension AudiobookContextMenuModifier {
    struct Preview: View {
        let audiobook: Audiobook
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                ItemProgressIndicatorImage(item: audiobook, size: .small, aspectRatio: .none)
                    .padding(.bottom, 12)
                
                Text(audiobook.name)
                    .font(.headline)
                    .modifier(SerifModifier())
                
                if !audiobook.authors.isEmpty {
                    Text(audiobook.authors, format: .list(type: .and, width: .short))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !audiobook.narrators.isEmpty {
                    Group {
                        Text("readBy")
                        + Text(audiobook.narrators, format: .list(type: .and, width: .short))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 240)
            .padding(20)
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .modifier(AudiobookContextMenuModifier(audiobook: Audiobook.fixture))
}
#endif
