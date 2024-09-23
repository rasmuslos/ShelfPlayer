//
//  Navigation.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import ShelfPlayerKit

internal struct Navigation {
    static let navigateNotification = Notification.Name("io.rfk.shelfPlayer.navigation")
    
    static let navigateAudiobookNotification = Notification.Name("io.rfk.shelfPlayer.navigation.audiobook")
    static let navigateAuthorNotification = Notification.Name("io.rfk.shelfPlayer.navigation.author")
    static let navigateSeriesNotification = Notification.Name("io.rfk.shelfPlayer.navigation.series")
    static let navigatePodcastNotification = Notification.Name("io.rfk.shelfPlayer.navigation.podcast")
    static let navigateEpisodeNotification = Notification.Name("io.rfk.shelfPlayer.navigation.episode")
    
    static let widthChangeNotification = Notification.Name("io.rfk.shelfPlayer.sidebar.width.changed")
    static let offsetChangeNotification = Notification.Name("io.rfk.shelfPlayer.sidebar.offset.changed")
}

internal extension Navigation {
    static func navigate(audiobookId: String) {
        NotificationCenter.default.post(name: Self.navigateAudiobookNotification, object: audiobookId)
    }
    static func navigate(authorId: String) {
        NotificationCenter.default.post(name: Self.navigateAuthorNotification, object: authorId)
    }
    static func navigate(seriesName: String) {
        NotificationCenter.default.post(name: Self.navigateSeriesNotification, object: seriesName)
    }
    static func navigate(podcastId: String) {
        NotificationCenter.default.post(name: Self.navigatePodcastNotification, object: podcastId)
    }
    static func navigate(episodeId: String, podcastId: String) {
        NotificationCenter.default.post(name: Self.navigateEpisodeNotification, object: (episodeId, podcastId))
    }
}

internal extension Navigation {
    struct NotificationModifier: ViewModifier {
        let navigateAudiobook: (String, String) -> Void
        let navigateAuthor: (String, String) -> Void
        let navigateSeries: (String, String) -> Void
        let navigatePodcast: (String, String) -> Void
        let navigateEpisode: (String, String, String) -> Void
        
        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAudiobookNotification)) { notification in
                    if let id = notification.object as? String {
                        Task {
                            let libraryID = try await AudiobookshelfClient.shared.item(itemId: id, episodeId: nil).0.libraryID
                            navigateAudiobook(id, libraryID)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAuthorNotification)) { notification in
                    if let id = notification.object as? String {
                        Task {
                            let libraryID = try await AudiobookshelfClient.shared.author(authorId: id).libraryID
                            navigateAuthor(id, libraryID)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateSeriesNotification)) { notification in
                    if let name = notification.object as? String {
                        Task {
                            // this is certainly something
                            
                            guard let libraries = try? await AudiobookshelfClient.shared.libraries().filter({ $0.type == .audiobooks }) else { return }
                            let fetched = await libraries.parallelMap { (try? await AudiobookshelfClient.shared.series(libraryID: $0.id, limit: 10_000, page: 0).0.filter { $0.name == name }) ?? [] }
                            
                            guard let libraryID = fetched.flatMap({ $0 }).first?.libraryID else { return }
                            navigateSeries(name, libraryID)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePodcastNotification)) { notification in
                    if let id = notification.object as? String {
                        Task {
                            let libraryID = try await AudiobookshelfClient.shared.podcast(podcastId: id).0.libraryID
                            navigatePodcast(id, libraryID)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateEpisodeNotification)) { notification in
                    if let (episodeId, podcastId) = notification.object as? (String, String) {
                        Task {
                            let libraryID = try await AudiobookshelfClient.shared.podcast(podcastId: podcastId).0.libraryID
                            navigateEpisode(episodeId, podcastId, libraryID)
                        }
                    }
                }
        }
    }
    struct NavigationModifier: ViewModifier {
        let didNavigate: () -> Void
        
        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAudiobookNotification)) { notification in
                    didNavigate()
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAuthorNotification)) { notification in
                    didNavigate()
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateSeriesNotification)) { notification in
                    didNavigate()
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePodcastNotification)) { notification in
                    didNavigate()
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateEpisodeNotification)) { notification in
                    didNavigate()
                }
        }
    }
    
    struct DestinationModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .navigationDestination(for: Navigation.AudiobookLoadDestination.self) { data in
                    AudiobookLoadView(audiobookId: data.audiobookId)
                }
                .navigationDestination(for: Navigation.AuthorLoadDestination.self) { data in
                    AuthorLoadView(authorId: data.authorId)
                }
                .navigationDestination(for: Navigation.SeriesLoadDestination.self) { data in
                    SeriesLoadView(series: .init(id: nil, name: data.seriesName, sequence: nil))
                }
                .navigationDestination(for: Navigation.PodcastLoadDestination.self) { data in
                    PodcastLoadView(podcastId: data.podcastId)
                }
                .navigationDestination(for: Navigation.EpisodeLoadDestination.self) { data in
                    EpisodeLoadView(id: data.episodeId, podcastId: data.podcastId)
                }
        }
    }
}

internal extension Navigation {
    struct AudiobookLoadDestination: Hashable {
        let audiobookId: String
    }
    
    struct AuthorLoadDestination: Hashable {
        let authorId: String
    }
    
    struct SeriesLoadDestination: Hashable {
        let seriesName: String
    }
    
    struct PodcastLoadDestination: Hashable {
        let podcastId: String
    }
    
    struct EpisodeLoadDestination: Hashable {
        let episodeId: String
        let podcastId: String
    }
}

internal extension EnvironmentValues {
    @Entry var library: Library = .init(id: "offine", name: "ShelfPlayer", type: .offline, displayOrder: -1)
}
