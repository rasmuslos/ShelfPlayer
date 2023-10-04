//
//  AudiobookLibraryView+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

extension AudiobookLibraryView {
    struct SeriesView: View {
        var body: some View {
            Text("Series")
                .tabItem {
                    Label("Series", systemImage: "books.vertical.fill")
                }
        }
    }
}
