//
//  PodcastView+Footer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 24.12.25.
//

import SwiftUI
import ShelfPlayback

extension PodcastView {
    struct Footer: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.colorScheme) private var colorScheme
        
        @Environment(PodcastViewModel.self) private var viewModel
        
        var body: some View {
            InformationListTitle(title: "item.information")
            
            InformationListRow(title: String(localized: "item.duration"), value: String(viewModel.episodes.reduce(0) { $0 + $1.duration }.formatted(.duration)))
            InformationListRow(title: String(localized: "item.related.podcast.episodes"), value: viewModel.episodeCount.formatted(.number))
            
            if !viewModel.podcast.genres.isEmpty {
                InformationListRow(title: String(localized: "item.genres"), value: viewModel.podcast.genres.formatted(.list(type: .and, width: .standard)))
            }
            
            if let publishingType = viewModel.podcast.publishingType {
                InformationListRow(title: "item.publishing", value: publishingType.label)
            }
            
            InformationListRow(title: String(localized: "item.rating"), value: viewModel.podcast.explicit ? String(localized: "item.explicit") : String(localized: "item.rating.safe"))
            
            #warning("todo: channel")
            
            InformationListTitle(title: "item.description")
            Description(description: viewModel.podcast.description, showHeadline: false)
                .listRowInsets(.init(top: 12, leading: 20, bottom: 0, trailing: 20))
        }
    }
}
