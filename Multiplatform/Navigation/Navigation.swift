//
//  Navigation.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import ShelfPlayerKit

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

extension Navigation {
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
                            let libraryId = try await AudiobookshelfClient.shared.item(itemId: id, episodeId: nil).0.libraryId
                            navigateAudiobook(id, libraryId)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAuthorNotification)) { notification in
                    if let id = notification.object as? String {
                        Task {
                            let libraryId = try await AudiobookshelfClient.shared.author(authorId: id).libraryId
                            navigateAuthor(id, libraryId)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateSeriesNotification)) { notification in
                    if let name = notification.object as? String {
                        Task {
                            guard let libraries = try? await AudiobookshelfClient.shared.libraries().filter({ $0.type == .audiobooks }) else { return }
                            let fetched = await libraries.parallelMap {
                                let series = try? await AudiobookshelfClient.shared.series(libraryId: $0.id).filter { $0.name == name }
                                return series ?? []
                            }
                            
                            // this is certainly something
                            guard let libraryId = fetched.flatMap({ $0 }).first?.libraryId else { return }
                            navigateSeries(name, libraryId)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePodcastNotification)) { notification in
                    if let id = notification.object as? String {
                        Task {
                            let libraryId = try await AudiobookshelfClient.shared.podcast(podcastId: id).0.libraryId
                            navigatePodcast(id, libraryId)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateEpisodeNotification)) { notification in
                    if let (episodeId, podcastId) = notification.object as? (String, String) {
                        Task {
                            let libraryId = try await AudiobookshelfClient.shared.podcast(podcastId: podcastId).0.libraryId
                            navigateEpisode(episodeId, podcastId, libraryId)
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

extension Navigation {
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

struct LibraryIdDefault: EnvironmentKey {
    static var defaultValue: String = ""
}
extension EnvironmentValues {
    var libraryId: String {
        get { self[LibraryIdDefault.self] }
        set { self[LibraryIdDefault.self] = newValue }
    }
}
