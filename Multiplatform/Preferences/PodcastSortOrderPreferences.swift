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
        Menu("preferences.defaultEpisodeSortOrder") {
            ItemSortOrderPicker(sortOrder: $sortOrder, ascending: $ascending)
        }
    }
}

#Preview {
    List {
        PodcastSortOrderPreferences()
    }
}
