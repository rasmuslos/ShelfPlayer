//
//  PodcastSortOrderPreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.07.25.
//

import SwiftUI
import ShelfPlayback

struct PodcastSortOrderPreferences: View {
    @Default(.defaultEpisodeSortOrder) private var sortOrder
    @Default(.defaultEpisodeAscending) private var ascending
    
    var body: some View {
        Menu {
            ItemSortOrderPicker(sortOrder: $sortOrder, ascending: $ascending)
        } label: {
            Label("preferences.defaultEpisodeSortOrder", systemImage: "arrow.up.arrow.down.square.fill")
        }
        .menuActionDismissBehavior(.disabled)
    }
}

#Preview {
    List {
        PodcastSortOrderPreferences()
    }
}
