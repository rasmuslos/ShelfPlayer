//
//  OfflineAudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPBase
import SPOffline

struct OfflineAudiobookList: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        ForEach(audiobooks) { audiobook in
            Button {
                audiobook.startPlayback()
            } label: {
                AudiobookRow(audiobook: audiobook)
                    .modifier(SwipeActionsModifier(item: audiobook))
            }
            .buttonStyle(.plain)
        }
    }
}

extension OfflineAudiobookList {
    struct AudiobookRow: View {
        let audiobook: Audiobook
        let entity: OfflineProgress
        
        @MainActor
        init(audiobook: Audiobook) {
            self.audiobook = audiobook
            entity = OfflineManager.shared.requireProgressEntity(item: audiobook)
        }
        
        var body: some View {
            HStack {
                ItemImage(image: audiobook.image)
                    .frame(height: 50)
                
                VStack(alignment: .leading) {
                    Text(audiobook.name)
                        .fontDesign(.serif)
                        .lineLimit(1)
                    
                    if let author = audiobook.author {
                        Text(author)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if entity.progress > 0 {
                    ProgressIndicator(entity: entity)
                        .frame(width: 20)
                }
            }
        }
    }
}

#Preview {
    List {
        OfflineAudiobookList(audiobooks: .init(repeating: [.fixture], count: 7))
    }
}
