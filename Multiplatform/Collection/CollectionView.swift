//
//  CollectionView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.07.25.
//

import SwiftUI
import ShelfPlayback

struct CollectionView: View {
    @Environment(Satellite.self) private var satellite
    @State private var viewModel: CollectionViewModel
    
    init(_ collection: ItemCollection) {
        _viewModel = .init(initialValue: .init(collection: collection))
    }
    
    @ViewBuilder
    private var listPresentation: some View {
        List {
            if let first = viewModel.first {
                PlayButton(item: first)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 20, bottom: 6, trailing: 20))
            }
            
            if let audiobooks = viewModel.audiobooks {
                AudiobookList(sections: audiobooks) { _ in }
            } else if let episodes = viewModel.episodes {
                EpisodeList(episodes: episodes, context: .collection, selected: .constant(nil))
            }
        }
        .listStyle(.plain)
    }
    
    var body: some View {
        Group {
            if viewModel.collection.items.isEmpty {
                EmptyCollectionView()
            } else {
                listPresentation
            }
        }
        .navigationTitle(viewModel.collection.name)
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("action.edit", systemImage: "pencil.circle") {
                    
                }
                Button("item.configure", systemImage: "gearshape.circle") {
                    satellite.present(.configureGrouping(viewModel.collection.id))
                }
            }
        }
        .environment(viewModel)
        .environment(\.displayContext, .collection(viewModel.collection))
        .modifier(PlaybackSafeAreaPaddingModifier())
        .userActivity("io.rfk.shelfplayer.item") { activity in
            activity.title = viewModel.collection.name
            activity.isEligibleForHandoff = true
            activity.isEligibleForPrediction = true
            activity.persistentIdentifier = viewModel.collection.id.description
            
            Task {
                try await activity.webpageURL = viewModel.collection.id.url
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CollectionView(.collectionFixture)
    }
    .previewEnvironment()
}
#Preview {
    NavigationStack {
        CollectionView(.playlistFixture)
    }
    .previewEnvironment()
}
#endif
