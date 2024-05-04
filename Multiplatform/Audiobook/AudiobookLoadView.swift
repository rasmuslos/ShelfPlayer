//
//  AudiobookLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import SPBase

struct AudiobookLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let audiobookId: String
    
    @State private var failed = false
    @State private var audiobook: Audiobook?
    
    var body: some View {
        if failed {
            AudiobookUnavailableView()
        } else if let audiobook = audiobook {
            AudiobookView(audiobook: audiobook)
        } else {
            LoadingView()
                .task { await fetchAudiobook() }
                .refreshable { await fetchAudiobook() }
        }
    }
    
    private func fetchAudiobook() async {
        failed = false
        
        if let audiobook = try? await AudiobookshelfClient.shared.getItem(itemId: audiobookId, episodeId: nil).0 as? Audiobook {
            self.audiobook = audiobook
        } else {
            failed = true
        }
    }
}
