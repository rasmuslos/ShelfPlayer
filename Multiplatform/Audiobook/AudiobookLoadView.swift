//
//  AudiobookLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import ShelfPlayerKit

internal struct AudiobookLoadView: View {
    let audiobookId: String
    
    @State private var failed = false
    @State private var audiobook: Audiobook?
    
    var body: some View {
        if let audiobook = audiobook {
            AudiobookView(audiobook)
        } else if failed {
            AudiobookUnavailableView()
                .refreshable {
                    await loadAudiobook()
                }
        } else {
            LoadingView()
                .task {
                    await loadAudiobook()
                }
                .refreshable {
                    await loadAudiobook()
                }
        }
    }
    
    private nonisolated func loadAudiobook() async {
        /*
        guard let audiobook = try? await AudiobookshelfClient.shared.item(itemId: audiobookId, episodeId: nil).0 as? Audiobook else {
            await MainActor.withAnimation {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.audiobook = audiobook
        }
         */
    }
}
