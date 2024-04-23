//
//  AudiobookLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import Defaults
import SPBase

extension AudiobookEntryView {
    struct LibraryView: View {
        var body: some View {
            NavigationStack {
                AudiobookLibraryView()
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.library", systemImage: "book.fill")
            }
        }
    }
}
