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
        private func row(title: LocalizedStringKey, value: String) -> some View {
            HStack(spacing: 0) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(value)
            }
            .font(.footnote)
        }
        
        var body: some View {
            Text("item.information")
                .font(.headline)
                .listRowSeparator(.hidden)
            
            row(title: "item.duration", value: String(viewModel.episodes.reduce(0) { $0 + $1.duration }.formatted(.duration)))
            row(title: "item.related.podcast.episodes", value: viewModel.episodeCount.formatted(.number))
            
            if !viewModel.podcast.genres.isEmpty {
                row(title: "item.genres", value: viewModel.podcast.genres.formatted(.list(type: .and, width: .standard)))
            }
            
            if let publishingType = viewModel.podcast.publishingType {
                row(title: "item.publishing", value: publishingType.label)
            }
            
            row(title: "item.channel", value: "ToDO")
            #warning("todo")
        }
    }
}
