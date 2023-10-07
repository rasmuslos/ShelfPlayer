//
//  PodcastLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct Home: View {
        var body: some View {
            Text(":)")
                .modifier(LibrarySelectorModifier())
                .tabItem {
                    Label("Home", systemImage: "waveform")
                }
        }
    }
}
