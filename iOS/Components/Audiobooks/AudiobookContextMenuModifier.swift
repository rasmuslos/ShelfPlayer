//
//  AudiobookContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 26.11.23.
//

import SwiftUI
import AudiobooksKit

struct AudiobookContextMenuModifier: ViewModifier {
    let audiobook: Audiobook
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                ToolbarProgressButton(item: audiobook)
                
                Divider()
                
                if audiobook.offline == .none {
                    Button {
                        Task {
                            try! await OfflineManager.shared.downloadAudiobook(audiobook)
                        }
                    } label: {
                        Label("download", systemImage: "arrow.down")
                    }
                } else {
                    Button {
                        try? OfflineManager.shared.deleteAudiobook(audiobookId: audiobook.id)
                    } label: {
                        Label("download.remove", systemImage: "trash")
                    }
                }
            } preview: {
                VStack(alignment: .leading) {
                    ItemProgressImage(item: audiobook)
                    
                    Text(audiobook.name)
                        .font(.headline)
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
            }
    }
}

#Preview {
    Text(":)")
        .modifier(AudiobookContextMenuModifier(audiobook: Audiobook.fixture))
}
