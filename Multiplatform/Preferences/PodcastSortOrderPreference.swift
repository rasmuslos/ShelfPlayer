//
//  PodcastSortOrderPreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.07.25.
//

import SwiftUI
import ShelfPlayback

struct PodcastSortOrderPreference<Content: View>: View {
    @Default(.defaultEpisodeSortOrder) private var sortOrder
    @Default(.defaultEpisodeAscending) private var ascending
    
    let buildLabel: (_ : LocalizedStringKey, _ : String) -> Content
    
    var body: some View {
        Menu {
            ItemSortOrderPicker(sortOrder: $sortOrder, ascending: $ascending)
        } label: {
            HStack(spacing: 0) {
                buildLabel("preferences.defaultEpisodeSortOrder", "arrow.up.arrow.down")
                
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
        PodcastSortOrderPreference {
            Label($0, systemImage: $1)
        }
    }
}
