//
//  PodcastLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import Defaults
import SPBase

extension PodcastEntryView {
    struct ListenNowView: View {
        var body: some View {
            NavigationStack {
                PodcastListenNowView()
                    .modifier(LibrarySelectorModifier())
            }
            .tabItem {
                Label("tab.home", systemImage: "waveform")
            }
        }
    }
}
