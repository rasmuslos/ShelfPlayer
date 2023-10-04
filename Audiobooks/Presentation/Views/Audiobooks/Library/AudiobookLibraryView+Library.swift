//
//  AudiobookLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

extension AudiobookLibraryView {
    struct LibraryView: View {
        var body: some View {
            Text("Library")
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
        }
    }
}
