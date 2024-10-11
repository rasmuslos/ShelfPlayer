//
//  PodcastView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastView: View {
    @Environment(\.library) private var library
    
    @State private var viewModel: PodcastViewModel
    
    init(_ podcast: Podcast, episodes: [Episode] = []) {
        _viewModel = .init(initialValue: .init(podcast: podcast, episodes: episodes))
    }
    
    var body: some View {
        List {
            Header()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if viewModel.episodes.isEmpty {
                ProgressIndicator()
            } else {
                HStack {
                    Text("episodes")
                        .bold()
                    
                    NavigationLink(destination: PodcastEpisodesView(viewModel: $viewModel)) {
                        HStack {
                            Spacer()
                            Text("episodes.all")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                EpisodeSingleList(episodes: viewModel.visible)
            }
        }
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .modifier(ToolbarModifier())
        .modifier(NowPlaying.SafeAreaModifier())
        .environment(viewModel)
        .onAppear {
            viewModel.library = library
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .sheet(isPresented: $viewModel.descriptionSheetPresented) {
            NavigationStack {
                ScrollView {
                    HStack(spacing: 0) {
                        if let description = viewModel.podcast.description {
                            Text(description)
                        } else {
                            Text("description.unavailable")
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .navigationTitle(viewModel.podcast.name)
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $viewModel.settingsSheetPresented) {
            PodcastSettingsSheet(podcast: viewModel.podcast, configuration: viewModel.fetchConfiguration)
        }
        .userActivity("io.rfk.shelfplayer.podcast") {
            $0.title = viewModel.podcast.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = viewModel.podcast.id
            $0.targetContentIdentifier = convertIdentifier(item: viewModel.podcast)
            $0.userInfo = [
                "libraryID": viewModel.podcast.libraryID,
                "podcastID": viewModel.podcast.id,
            ]
            $0.webpageURL = viewModel.podcast.url
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastView(Podcast.fixture, episodes: .init(repeating: [.fixture], count: 7))
    }
    .environment(NowPlaying.ViewModel())
}
#endif
