//
//  AudiobookLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import SPBase

internal struct AudiobookLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let audiobookId: String
    
    @State private var failed = false
    @State private var audiobook: Audiobook?
    
    var body: some View {
        if let audiobook = audiobook {
            AudiobookView(viewModel: .init(audiobook: audiobook))
        } else if failed {
            AudiobookUnavailableView()
                .refreshable { await loadAudiobook() }
        } else {
            LoadingView()
                .task { await loadAudiobook() }
        }
    }
    
    private func loadAudiobook() async {
        guard let audiobook = try? await AudiobookshelfClient.shared.getItem(itemId: audiobookId, episodeId: nil).0 as? Audiobook else {
            failed = true
            return
        }
        
        self.audiobook = audiobook
    }
}
