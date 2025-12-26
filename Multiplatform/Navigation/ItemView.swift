//
//  ItemView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 22.07.25.
//

import SwiftUI
import ShelfPlayback

struct ItemView: View {
    let item: Item
    
    var zoomID: UUID?
    
    var body: some View {
        if let audiobook = item as? Audiobook {
            AudiobookView(audiobook)
        } else if let series = item as? Series {
            SeriesView(series)
        } else if let person = item as? Person {
            PersonView(person)
        } else if let podcast = item as? Podcast {
            PodcastView(podcast, zoom: zoomID != nil)
        } else if let episode = item as? Episode {
            EpisodeView(episode, zoomID: zoomID)
        } else if let collection = item as? ItemCollection {
            CollectionView(collection)
        } else {
            ErrorView()
        }
    }
}
