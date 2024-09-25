//
//  EpisodeUnavailableView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct PodcastUnavailableView: View {
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView("error.unavailable.podcast", systemImage: "rectangle.stack", description: Text("error.unavailable.text"))
        }
    }
}

#Preview {
    PodcastUnavailableView()
}
