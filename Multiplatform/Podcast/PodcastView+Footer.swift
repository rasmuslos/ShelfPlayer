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
        
        @ViewBuilder
        private func title(_ title: LocalizedStringKey) -> some View {
            Text(title)
                .font(.headline)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 12, leading: 20, bottom: 0, trailing: 20))
        }
        @ViewBuilder
        private func row(title: LocalizedStringKey, value: String) -> some View {
            HStack(spacing: 0) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(value)
            }
            .font(.footnote)
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
        }
        
        var body: some View {
            title("item.information")
            
            row(title: "item.duration", value: String(viewModel.episodes.reduce(0) { $0 + $1.duration }.formatted(.duration)))
            row(title: "item.related.podcast.episodes", value: viewModel.episodeCount.formatted(.number))
            
            if !viewModel.podcast.genres.isEmpty {
                row(title: "item.genres", value: viewModel.podcast.genres.formatted(.list(type: .and, width: .standard)))
            }
            
            if let publishingType = viewModel.podcast.publishingType {
                row(title: "item.publishing", value: publishingType.label)
            }
            
            row(title: "item.rating", value: viewModel.podcast.explicit ? String(localized: "item.explicit") : String(localized: "item.rating.safe"))
            
            #warning("todo: channel")
            
            title("item.description")
            Description(description: viewModel.podcast.description, showHeadline: false)
                .listRowInsets(.init(top: 8, leading: 20, bottom: 0, trailing: 20))
        }
    }
}
