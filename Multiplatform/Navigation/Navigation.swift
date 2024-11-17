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
    static func navigate(audiobookID: String, libraryID: String) {
        NotificationCenter.default.post(name: Self.navigateAudiobookNotification, object: nil, userInfo: [
            "libraryID": libraryID,
            "audiobookID": audiobookID,
        ])
    }
    static func navigate(authorID: String, libraryID: String) {
        NotificationCenter.default.post(name: Self.navigateAuthorNotification, object: nil, userInfo: [
            "libraryID": libraryID,
            "authorID": authorID,
        ])
    }
    static func navigate(authorName: String, libraryID: String) {
        NotificationCenter.default.post(name: Self.navigateAuthorNotification, object: nil, userInfo: [
            "libraryID": libraryID,
            "authorName": authorName,
        ])
    }
    static func navigate(seriesID: String, libraryID: String) {
        NotificationCenter.default.post(name: Self.navigateSeriesNotification, object: nil, userInfo: [
            "libraryID": libraryID,
            "seriesID": seriesID,
        ])
    }
    static func navigate(seriesName: String, libraryID: String) {
        NotificationCenter.default.post(name: Self.navigateSeriesNotification, object: nil, userInfo: [
            "libraryID": libraryID,
            "seriesName": seriesName,
        ])
    }
    static func navigate(podcastID: String, libraryID: String) {
        NotificationCenter.default.post(name: Self.navigateAuthorNotification, object: nil, userInfo: [
            "libraryID": libraryID,
            "podcastID": podcastID,
        ])
    }
    static func navigate(episodeID: String, podcastID: String, libraryID: String) {
        NotificationCenter.default.post(name: Self.navigateAuthorNotification, object: nil, userInfo: [
            "libraryID": libraryID,
            "episodeID": episodeID,
            "podcastID": podcastID,
        ])
    }
}

internal extension Navigation {
    struct NotificationModifier: ViewModifier {
        typealias Callback = (_ libraryID: String, _ audiobookID: String?, _ authorName: String?, _ authorID: String?, _ seriesName: String?, _ seriesID: String?, _ podcastID: String?, _ episodeID: String?) -> Void
        
        let didNavigate: Callback
        
        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAudiobookNotification)) {
                    handle(notification: $0)
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateAuthorNotification)) {
                    handle(notification: $0)
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateSeriesNotification)) {
                    handle(notification: $0)
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigatePodcastNotification)) {
                    handle(notification: $0)
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateEpisodeNotification)) {
                    handle(notification: $0)
                }
        }
        
        private func handle(notification: Notification) {
            guard let userInfo = notification.userInfo as? [String: String] else {
                return
            }
            
            guard let libraryID = userInfo["libraryID"] else {
                return
            }
            
            didNavigate(libraryID, userInfo["audiobookID"], userInfo["authorName"], userInfo["authorID"], userInfo["seriesName"], userInfo["seriesID"], userInfo["podcastID"], userInfo["episodeID"])
        }
    }
    
    struct DestinationModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .navigationDestination(for: Navigation.AudiobookLoadDestination.self) { data in
                    AudiobookLoadView(audiobookId: data.audiobookId)
                }
                .navigationDestination(for: Navigation.AuthorLoadDestination.self) { data in
                    if let authorID = data.authorId {
                        AuthorLoadView(authorID: authorID)
                    } else if let authorName = data.authorName {
                        AuthorLoadView(authorName: authorName)
                    }
                }
                .navigationDestination(for: Navigation.SeriesLoadDestination.self) { data in
                    if let seriesID = data.seriesId {
                        SeriesLoadView(seriesID: seriesID)
                    } else if let seriesName = data.seriesName {
                        SeriesLoadView(seriesName: seriesName)
                    }
                }
                .navigationDestination(for: Navigation.PodcastLoadDestination.self) { data in
                    PodcastLoadView(podcastID: data.podcastId, zoom: false)
                }
                .navigationDestination(for: Navigation.EpisodeLoadDestination.self) { data in
                    EpisodeLoadView(id: data.episodeId, podcastId: data.podcastId, zoom: false)
                }
        }
    }
}

internal extension Navigation {
    struct AudiobookLoadDestination: Hashable {
        let audiobookId: String
    }
    
    struct AuthorLoadDestination: Hashable {
        let authorId: String?
        let authorName: String?
        
        init(authorId: String) {
            self.authorId = authorId
            authorName = nil
        }
        init(authorName: String) {
            authorId = nil
            self.authorName = authorName
        }
    }
    
    struct SeriesLoadDestination: Hashable {
        let seriesId: String?
        let seriesName: String?
        
        init(seriesId: String) {
            self.seriesId = seriesId
            seriesName = nil
        }
        init(seriesName: String) {
            seriesId = nil
            self.seriesName = seriesName
        }
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
