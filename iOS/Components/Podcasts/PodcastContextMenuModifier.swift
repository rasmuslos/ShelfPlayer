//
//  PodcastContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.11.23.
//

import SwiftUI
import ShelfPlayerKit

struct PodcastContextMenuModifier: ViewModifier {
    let id: String
    let name: String
    @State var author: String?
    @State var description: String?
    
    let image: Item.Image?
    
    @State var filter: EpisodeFilterSortMenu.Filter
    @State var sortOrder: EpisodeFilterSortMenu.SortOrder
    @State var ascending: Bool
    
    init(id: String, name: String, author: String?, description: String?, image: Item.Image?) {
        self.id = id
        self.name = name
        _author = State(initialValue: author)
        _description = State(initialValue: description)
        self.image = image
        
        _filter = State(initialValue: EpisodeFilterSortMenu.getFilter(podcastId: id))
        _sortOrder = State(initialValue: EpisodeFilterSortMenu.getSortOrder(podcastId: id))
        _ascending = State(initialValue: EpisodeFilterSortMenu.getAscending(podcastId: id))
    }
    
    init(podcast: Podcast) {
        self.init(id: podcast.id, name: podcast.name, author: podcast.author, description: podcast.description, image: podcast.image)
    }
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                NavigationLink(destination: PodcastLoadView(podcastId: id)) {
                    Label("podcast.view", systemImage: "tray.full")
                }
                
                Divider()
                
                EpisodeFilterSortMenu(podcastId: id, filter: $filter, sortOrder: $sortOrder, ascending: $ascending)
            } preview: {
                HStack {
                    VStack(alignment: .leading) {
                        ItemImage(image: image)
                            .frame(width: 50)
                        
                        Text(name)
                            .font(.headline)
                            .padding(.top, 10)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let author = author {
                            Text(author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let description = description {
                            Text(description)
                                .lineLimit(7)
                                .padding(.top, 10)
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 300)
                .padding(20)
            }
            .onAppear {
                if author == nil && description == nil {
                    Task.detached {
                        if let (podcast, _) = await AudiobookshelfClient.shared.getPodcast(podcastId: id) {
                            withAnimation {
                                author = podcast.author
                                description = podcast.description
                            }
                        }
                    }
                }
            }
    }
}

#Preview {
    Text(":)")
        .modifier(PodcastContextMenuModifier(podcast: Podcast.fixture))
}
