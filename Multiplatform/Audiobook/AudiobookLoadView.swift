//
//  AudiobookLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import ShelfPlayerKit

internal struct AudiobookLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let audiobookId: String
    
    @State private var failed = false
    @State private var audiobook: Audiobook?
    
    var body: some View {
        if let audiobook = audiobook {
            AudiobookView(audiobook)
        } else if failed {
            AudiobookUnavailableView()
                .refreshable { await loadAudiobook() }
        } else {
            LoadingView()
                .task { await loadAudiobook() }
        }
    }
    
    private func loadAudiobook() async {
        guard let audiobook = try? await AudiobookshelfClient.shared.item(itemId: audiobookId, episodeId: nil).0 as? Audiobook else {
            failed = true
            return
        }
        
        self.audiobook = audiobook
    }
}
