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
    
    private var origin: AudioPlayerItem.PlaybackOrigin {
        .collection(viewModel.collection.id)
    }
    
    @ViewBuilder
    private var listPresentation: some View {
        List {
            if let description = viewModel.collection.description {
                Button {
                    satellite.present(.description(viewModel.collection))
                } label: {
                    Text(description)
                        .lineLimit(5)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 20, bottom: 12, trailing: 20))
            }
            
            if let highlighted = viewModel.highlighted {
                PlayButton(item: highlighted)
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
        .id(viewModel.id)
        .navigationTitle(viewModel.collection.name)
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "ellipsis.circle") {
                    if let highlighted = viewModel.highlighted {
                        Button {
                            satellite.start(highlighted.id, origin: origin)
                        } label: {
                            Label("item.play", systemImage: "play.fill")
                        }
                        Button {
                            satellite.queue(viewModel.collection.items.map(\.id), origin: origin)
                        } label: {
                            Label("playback.queue.add", systemImage: QueueButton.systemImage)
                        }
                        
                        Divider()
                    }
                    
                    ItemConfigureButton(itemID: viewModel.collection.id)
                    
                    Divider()
                    
                    Button("action.edit", systemImage: "pencil") {
                        satellite.present(.editCollection(viewModel.collection))
                    }
                    
                    if viewModel.collection.id.type == .collection {
                        Button("item.collection.createPlaylist", systemImage: ItemIdentifier.ItemType.playlist.icon) {
                            viewModel.createPlaylist()
                        }
                    }
                    
                    Button("action.delete", systemImage: "trash", role: .destructive) {
                        viewModel.delete()
                    }
                }
            }
        }
        .environment(viewModel)
        .environment(\.displayContext, .collection(viewModel.collection))
        .refreshable {
            viewModel.refresh()
        }
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
