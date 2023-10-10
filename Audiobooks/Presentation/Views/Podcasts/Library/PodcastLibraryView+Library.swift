//
//  PodcastLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct LibraryView: View {
        var body: some View {
            Text(":)")
                .modifier(NowPlayingBarModifier())
                .tabItem {
                    Label("Library", systemImage: "tray.full")
                }
        }
    }
}
