//
//  PodcastLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct Library: View {
        var body: some View {
            Text(":)")
                .tabItem {
                    Label("Library", systemImage: "tray.full")
                }
        }
    }
}
