//
//  PodcastSortOrderPreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.07.25.
//

import SwiftUI
import ShelfPlayback

struct PodcastSortOrderPreference: View {
    @Default(.defaultEpisodeSortOrder) private var sortOrder
    @Default(.defaultEpisodeAscending) private var ascending
    
    var body: some View {
        Menu {
            ItemSortOrderPicker(sortOrder: $sortOrder, ascending: $ascending)
        } label: {
            HStack(spacing: 0) {
                Label("preferences.defaultEpisodeSortOrder", systemImage: "arrow.up.arrow.down.square")
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .menuActionDismissBehavior(.disabled)
    }
}

#Preview {
    List {
        PodcastSortOrderPreference()
    }
}
