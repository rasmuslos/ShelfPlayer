//
//  PodcastLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

extension PodcastEntryView {
    struct LibraryView: View {
        var body: some View {
            NavigationStack {
                PodcastLibraryView()
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.library", systemImage: "tray.full")
            }
        }
    }
}
