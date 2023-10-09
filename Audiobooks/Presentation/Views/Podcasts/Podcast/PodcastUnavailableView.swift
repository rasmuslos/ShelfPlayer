//
//  EpisodeUnavailableView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct PodcastUnavailableView: View {
    var body: some View {
        ContentUnavailableView("Podcast unavailable", systemImage: "waveform", description: Text("Please ensure that you are connected to the internet"))
    }
}

#Preview {
    PodcastUnavailableView()
}
