//
//  Navigation.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI

struct Navigation {
    static let navigateNotification = NSNotification.Name("io.rfk.shelfPlayer.navigation")
    
    static let navigateAudiobookNotification = NSNotification.Name("io.rfk.shelfPlayer.navigation.audiobook")
    static let navigateAuthorNotification = NSNotification.Name("io.rfk.shelfPlayer.navigation.author")
    static let navigateSeriesNotification = NSNotification.Name("io.rfk.shelfPlayer.navigation.series")
    static let navigatePodcastNotification = NSNotification.Name("io.rfk.shelfPlayer.navigation.podcast")
    static let navigateEpisodeNotification = NSNotification.Name("io.rfk.shelfPlayer.navigation.episode")
    
    static let widthChangeNotification = NSNotification.Name("io.rfk.shelfPlayer.sidebar.width.changed")
    static let offsetChangeNotification = NSNotification.Name("io.rfk.shelfPlayer.sidebar.offset.changed")
}

extension Navigation {
    func navigate(audiobookId: String) {
        NotificationCenter.default.post(name: Self.navigateAudiobookNotification, object: audiobookId)
    }
    func navigate(authorId: String) {
        NotificationCenter.default.post(name: Self.navigateAuthorNotification, object: authorId)
    }
    func navigate(seriesId: String) {
        NotificationCenter.default.post(name: Self.navigateSeriesNotification, object: seriesId)
    }
    func navigate(podcastId: String) {
        NotificationCenter.default.post(name: Self.navigatePodcastNotification, object: podcastId)
    }
    func navigate(episodeId: String) {
        NotificationCenter.default.post(name: Self.navigateEpisodeNotification, object: episodeId)
    }
}

extension Navigation {
    struct NotificationModifier: ViewModifier {
        let navigateAudiobook: (String) -> Void
        let navigateAuthor: (String) -> Void
        let navigateSeries: (String) -> Void
        let navigatePodcast: (String) -> Void
        let navigateEpisode: (String) -> Void
        
        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAudiobookNotification)) { notification in
                    if let id = notification.object as? String {
                        navigateAudiobook(id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAuthorNotification)) { notification in
                    if let id = notification.object as? String {
                        navigateSeries(id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateSeriesNotification)) { notification in
                    if let id = notification.object as? String {
                        navigateSeries(id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePodcastNotification)) { notification in
                    if let id = notification.object as? String {
                        navigatePodcast(id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateEpisodeNotification)) { notification in
                    if let id = notification.object as? String {
                        navigateEpisode(id)
                    }
                }
        }
    }
    
    struct DestinationModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .navigationDestination(for: Navigation.AudiobookLoadDestination.self) { data in
                    
                }
                .navigationDestination(for: Navigation.AuthorLoadDestination.self) { data in
                    AuthorLoadView(authorId: data.authorId)
                }
                .navigationDestination(for: Navigation.SeriesLoadDestination.self) { data in
                    SeriesLoadView(series: .init(id: data.seriesId, name: "Unknown", sequence: nil))
                }
                .navigationDestination(for: Navigation.PodcastLoadDestination.self) { data in
                    PodcastLoadView(podcastId: data.podcastId)
                }
                .navigationDestination(for: Navigation.EpisodeLoadDestination.self) { data in
                    
                }
        }
    }
}

extension Navigation {
    struct AudiobookLoadDestination: Hashable {
        let audiobookId: String
    }
    
    struct AuthorLoadDestination: Hashable {
        let authorId: String
    }
    
    struct SeriesLoadDestination: Hashable {
        let seriesId: String
    }
    
    struct PodcastLoadDestination: Hashable {
        let podcastId: String
    }
    
    struct EpisodeLoadDestination: Hashable {
        let episodeId: String
    }
}
