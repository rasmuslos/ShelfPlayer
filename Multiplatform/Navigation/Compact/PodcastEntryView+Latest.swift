//
//  PodcastLibraryView+Latest.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

extension PodcastEntryView {
    struct LatestView: View {
        var body: some View {
            NavigationStack {
                PodcastLatestView()
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.latest", systemImage: "clock")
            }
        }
    }
}
