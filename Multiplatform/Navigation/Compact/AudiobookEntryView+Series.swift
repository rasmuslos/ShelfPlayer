//
//  AudiobookLibraryView+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import SPBase

extension AudiobookEntryView {
    struct SeriesView: View {
        var body: some View {
            NavigationStack {
                AudiobookSeriesView()
            }
            .tabItem {
                Label("tab.series", systemImage: "books.vertical.fill")
            }
        }
    }
}
