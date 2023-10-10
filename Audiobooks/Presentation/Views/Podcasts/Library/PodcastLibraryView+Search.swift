//
//  PodcastLibraryView+Search.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct SearchView: View {
        var body: some View {
            Text(":)")
                .modifier(NowPlayingBarModifier())
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }
}
