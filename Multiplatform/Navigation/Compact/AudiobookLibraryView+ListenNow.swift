//
//  AudiobookLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

extension AudiobookEntryView {
    struct ListenNowView: View {
        
        var body: some View {
            NavigationStack {
                AudiobookListenNowView()
                    .modifier(LibrarySelectorModifier())
            }
            .modifier(CompactNowPlayingBarModifier())
            .tabItem {
                Label("tab.home", systemImage: "bookmark.fill")
            }
        }
    }
}
