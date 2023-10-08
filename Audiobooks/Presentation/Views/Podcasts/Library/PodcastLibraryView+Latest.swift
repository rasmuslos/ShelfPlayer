//
//  PodcastLibraryView+Latest.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct LatestView: View {
        var body: some View {
            Text(":)")
                .tabItem {
                    Label("Latest", systemImage: "clock")
                }
        }
    }
}
